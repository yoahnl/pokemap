import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'battle_move_recipe_compiler.dart';

enum BattleRecipeFallbackReason {
  unbound,
  unavailableCapabilities,
  incompletePresentation,
  resourceBudget,
}

final class BattleOfflineRecipeLoadCancelled implements Exception {
  const BattleOfflineRecipeLoadCancelled();
}

final class BattleOfflineMoveRecipeResult {
  BattleOfflineMoveRecipeResult({
    required this.fallbackReason,
    this.prepared,
    this.verifiedMedia,
    Set<String> unavailableCapabilities = const {},
  }) : unavailableCapabilities = Set.unmodifiable(unavailableCapabilities);

  final BattleRecipeFallbackReason? fallbackReason;
  final PreparedBattleMoveRecipe? prepared;
  final BattleOfflineVerifiedMedia? verifiedMedia;
  final Set<String> unavailableCapabilities;
}

final class BattleOfflineVerifiedMedia {
  BattleOfflineVerifiedMedia._(
    this._bundle,
    this._reservation,
    this._budget,
    this._textureDecodeBytes,
  );

  InspectedBattleRecipeBundle? _bundle;
  RuntimeResourceReservation? _reservation;
  final RuntimeResourceBudget _budget;
  final int _textureDecodeBytes;

  InspectedBattleRecipeBundle get bundle {
    final bundle = _bundle;
    final reservation = _reservation;
    if (bundle == null || reservation == null) {
      throw StateError('Battle recipe media already released');
    }
    reservation.ensureCurrent();
    return bundle;
  }

  Future<RuntimeResourceReservation> acquireTextureDecode({
    bool Function()? isCurrent,
  }) {
    final reservation = _reservation;
    if (reservation == null) {
      throw StateError('Battle recipe media already released');
    }
    reservation.ensureCurrent();
    return _budget.acquire(
      transientBytes: _textureDecodeBytes,
      isCurrent: () {
        try {
          if (!identical(_reservation, reservation)) return false;
          reservation.ensureCurrent();
          return isCurrent?.call() ?? true;
        } on Object {
          return false;
        }
      },
    );
  }

  void release() {
    _bundle = null;
    _reservation?.release();
    _reservation = null;
  }
}

final class BattleOfflineMoveRecipeLoader {
  BattleOfflineMoveRecipeLoader({
    required this.projectRootDirectory,
    RuntimeResourceBudget? resourceBudget,
  }) : _resourceBudget = resourceBudget ?? RuntimeResourceBudget();

  final String projectRootDirectory;
  final RuntimeResourceBudget _resourceBudget;

  static const _limits = BattleRecipeBundleLimits(
    maxTextures: 256,
    maxTextureBytes: 8 * 1024 * 1024,
    maxBundleBytes: 64 * 1024 * 1024,
    maxDimension: 2048,
    maxTexturePixels: 4000000,
    maxTotalPixels: 16000000,
  );

  Future<BattleOfflineMoveRecipeResult> load(
    String projectMoveId, {
    bool Function()? isCurrent,
    bool retainVerifiedMedia = false,
  }) async {
    _checkCurrent(isCurrent);
    final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
    _checkCurrent(isCurrent);
    late final String bindingPath;
    try {
      bindingPath = battleRecipeBindingPath(projectMoveId);
    } on FormatException {
      return BattleOfflineMoveRecipeResult(
        fallbackReason: BattleRecipeFallbackReason.unbound,
      );
    }
    final bindingType = await FileSystemEntity.type(
      p.join(root, bindingPath),
      followLinks: false,
    );
    _checkCurrent(isCurrent);
    if (bindingType == FileSystemEntityType.notFound) {
      return BattleOfflineMoveRecipeResult(
        fallbackReason: BattleRecipeFallbackReason.unbound,
      );
    }
    RuntimeResourceReservation? reservation;
    try {
      reservation = await _resourceBudget.acquire(
        transientBytes: 2 * 65536,
        isCurrent: isCurrent,
      );
      final bindingBytes = await _read(
        root,
        bindingPath,
        maximumBytes: 65536,
        isCurrent: isCurrent,
      );
      reservation.resize(
        residentBytes: 0,
        transientBytes: bindingBytes.length * 64 + 2 * 1048576 + 65536,
      );
      final decoded = decodeBoundedBattleJson(
        bindingBytes,
        maxDepth: 16,
        label: 'Battle recipe binding',
      );
      if (decoded is! Map<String, dynamic> ||
          decoded['kind'] != 'avelune.battle-recipe-binding') {
        return BattleOfflineMoveRecipeResult(
          fallbackReason: BattleRecipeFallbackReason.unbound,
        );
      }
      final binding = BattleRecipeProjectBinding.fromJson(decoded).binding;
      if (binding.projectMoveId != projectMoveId) {
        throw const FormatException(
          'Battle recipe belongs to a different move',
        );
      }
      final result = await _loadBound(
        root,
        binding,
        projectMoveId,
        reservation,
        isCurrent,
        bindingBytes.length,
        retainVerifiedMedia,
      );
      _checkCurrent(isCurrent);
      if (result.verifiedMedia != null) {
        reservation.ensureCurrent();
        reservation = null;
      }
      return result;
    } on RuntimeResourceAdmissionException {
      _checkCurrent(isCurrent);
      return BattleOfflineMoveRecipeResult(
        fallbackReason: BattleRecipeFallbackReason.resourceBudget,
      );
    } finally {
      reservation?.release();
    }
  }

  Future<BattleOfflineMoveRecipeResult> _loadBound(
    String root,
    BattleMoveRecipeBinding binding,
    String projectMoveId,
    RuntimeResourceReservation reservation,
    bool Function()? isCurrent,
    int bindingByteLength,
    bool retainVerifiedMedia,
  ) async {
    final recipeBytes = await _read(
      root,
      battleRecipeBlobPath(
        binding.recipeSha256,
        'application/vnd.avelune.battle-recipe+json',
        projectMoveId: projectMoveId,
      ),
      maximumBytes: 1048576,
      isCurrent: isCurrent,
    );
    var jsonBytes = bindingByteLength + recipeBytes.length;
    reservation.resize(
      residentBytes: 0,
      transientBytes: jsonBytes * 64 + recipeBytes.length * 5 + 2 * 65536,
    );
    final recipe = binding.inspectRecipe(recipeBytes);
    var totalBytes = recipeBytes.length;
    for (final resource in recipe.resources) {
      final maxBytes = switch (resource.role) {
        'texture' => _limits.maxTextureBytes,
        'particleDefinition' => 262144,
        'sound' => BattleRecipeBundleInspector.maxSoundBytes,
        _ => throw const FormatException('Unsupported battle recipe resource'),
      };
      totalBytes += resource.sizeBytes;
      if (resource.sizeBytes > maxBytes ||
          totalBytes > _limits.maxBundleBytes) {
        throw const FormatException('Battle recipe bundle exceeds byte limit');
      }
      if (resource.sizeBytes > _resourceBudget.profile.maximumEncodedBytes) {
        throw const RuntimeResourceAdmissionException('encoded_bytes');
      }
      if (resource.role == 'particleDefinition') {
        jsonBytes += resource.sizeBytes;
      }
    }
    final encodedReservation = totalBytes * 5 + jsonBytes * 64 + 2 * 65536;
    reservation.resize(residentBytes: 0, transientBytes: encodedReservation);
    final media = <String, Uint8List>{};
    var largestTexturePixels = 0;
    var totalTexturePixels = 0;
    for (final resource in recipe.resources) {
      final bytes = await _read(
        root,
        battleRecipeBlobPath(
          resource.sha256Hex,
          resource.mediaType,
          projectMoveId: projectMoveId,
        ),
        maximumBytes: resource.sizeBytes,
        isCurrent: isCurrent,
      );
      if (bytes.length != resource.sizeBytes) {
        throw const FormatException('Battle recipe resource size mismatch');
      }
      media[resource.id] = bytes;
      if (resource.role == 'texture') {
        final dimensions = decodeRasterImageDimensions(
          bytes,
          mediaType: 'image/png',
        );
        if (dimensions == null ||
            dimensions.width < 1 ||
            dimensions.height < 1 ||
            dimensions.width > _limits.maxDimension ||
            dimensions.height > _limits.maxDimension) {
          throw const FormatException(
            'Invalid battle recipe texture dimensions',
          );
        }
        final pixels = dimensions.width * dimensions.height;
        totalTexturePixels += pixels;
        if (pixels > _limits.maxTexturePixels ||
            totalTexturePixels > _limits.maxTotalPixels) {
          throw const FormatException(
            'Battle recipe texture exceeds pixel limit',
          );
        }
        if (pixels > largestTexturePixels) largestTexturePixels = pixels;
      }
    }
    reservation.resize(
      residentBytes: 0,
      transientBytes: encodedReservation + largestTexturePixels * 16,
    );
    InspectedBattleRecipeBundle inspect() =>
        const BattleRecipeBundleInspector().inspect(
          binding,
          recipeBytes,
          media,
          limits: _limits,
          availableCapabilities:
              BattleMoveAnimationRecipe.recognizedCapabilities,
          expectedProjectMoveId: projectMoveId,
          expectedCatalogReleaseId: binding.catalogReleaseId,
        );
    final inspected = media.isEmpty ? inspect() : await Isolate.run(inspect);
    _checkCurrent(isCurrent);
    final unavailable = inspected.recipe.unsupportedCapabilities(
      BattleMoveRecipeCompiler.availableCapabilities,
    );
    final prepared = unavailable.isNotEmpty
        ? null
        : const BattleMoveRecipeCompiler().prepareBound(
            binding,
            inspected.recipeBytes,
            inspected.media,
            expectedProjectMoveId: projectMoveId,
            expectedCatalogReleaseId: binding.catalogReleaseId,
          );
    BattleOfflineVerifiedMedia? verifiedMedia;
    if (retainVerifiedMedia) {
      reservation.resize(
        residentBytes: totalBytes * 2 + jsonBytes * 64 + totalTexturePixels * 8,
        transientBytes: encodedReservation + largestTexturePixels * 16,
      );
      _checkCurrent(isCurrent);
      reservation.commit();
      verifiedMedia = BattleOfflineVerifiedMedia._(
        inspected,
        reservation,
        _resourceBudget,
        largestTexturePixels * 16,
      );
    }
    return BattleOfflineMoveRecipeResult(
      fallbackReason: unavailable.isNotEmpty
          ? BattleRecipeFallbackReason.unavailableCapabilities
          : BattleMoveRecipeCompiler.supportsCompleteMoveVisuals
          ? null
          : BattleRecipeFallbackReason.incompletePresentation,
      prepared: prepared,
      verifiedMedia: verifiedMedia,
      unavailableCapabilities: unavailable,
    );
  }

  Future<Uint8List> _read(
    String root,
    String relativePath, {
    required int maximumBytes,
    bool Function()? isCurrent,
  }) async {
    final file = File(p.join(root, relativePath));
    try {
      _checkCurrent(isCurrent);
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      _checkCurrent(isCurrent);
      if (type == FileSystemEntityType.notFound) {
        throw const FormatException('Battle recipe resource is unavailable');
      }
      final resolved = await file.resolveSymbolicLinks();
      _checkCurrent(isCurrent);
      if (!p.isWithin(root, resolved) ||
          await FileSystemEntity.type(resolved, followLinks: false) !=
              FileSystemEntityType.file) {
        throw const FormatException('Invalid battle recipe resource path');
      }
      final output = BytesBuilder(copy: false);
      await for (final chunk in File(resolved).openRead()) {
        _checkCurrent(isCurrent);
        if (output.length + chunk.length > maximumBytes) {
          throw const FormatException(
            'Battle recipe resource exceeds byte limit',
          );
        }
        output.add(chunk);
      }
      _checkCurrent(isCurrent);
      return output.takeBytes();
    } on FileSystemException {
      throw const FormatException('Battle recipe resource is unavailable');
    }
  }
}

void _checkCurrent(bool Function()? isCurrent) {
  if (isCurrent != null && !isCurrent()) {
    throw const BattleOfflineRecipeLoadCancelled();
  }
}
