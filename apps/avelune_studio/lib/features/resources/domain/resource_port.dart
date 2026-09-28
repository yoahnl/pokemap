import 'dart:typed_data';
import 'package:map_core/map_core_domain.dart';

final class ResourceImageImport {
  const ResourceImageImport({
    required this.sourcePath,
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String sourcePath;
  final String name;
  final int tileWidth;
  final int tileHeight;
}

final class BorderCreationRequest {
  const BorderCreationRequest({
    required this.name,
    this.capElementId,
    this.straightElementId,
    this.cornerElementId,
    this.blueprintId,
    this.publish = true,
    this.acceptedWarningCodes = const [],
  });

  final String name;
  final String? capElementId;
  final String? straightElementId;
  final String? cornerElementId;
  final String? blueprintId;
  final bool publish;
  final List<String> acceptedWarningCodes;
}

final class CharacterPortraitImport {
  const CharacterPortraitImport({
    required this.sourcePath,
    required this.characterId,
    required this.portraitStateId,
  });

  final String sourcePath;
  final String characterId;
  final String portraitStateId;
}

final class ResourceMutationReceipt {
  const ResourceMutationReceipt({
    required this.before,
    required this.manifest,
    required this.beforeRevision,
    required this.revision,
    required this.changedPaths,
    this.createdTilesetId,
  });

  final ProjectManifest before;
  final ProjectManifest manifest;
  final String beforeRevision;
  final String revision;
  final List<String> changedPaths;
  final String? createdTilesetId;
}

abstract interface class ResourcePort {
  Future<ResourceMutationReceipt> importImage(ResourceImageImport request);

  Future<ResourceMutationReceipt> createBorder(BorderCreationRequest request);

  Future<ResourceMutationReceipt> importCharacterPortrait(
    CharacterPortraitImport request,
  );

  Future<Uint8List?> readCharacterPortrait(
    String characterId,
    String portraitStateId,
  );

  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  );

  Future<ResourceMutationReceipt> saveElement(ProjectElementEntry element);

  Future<void> dispose();
}

final class ResourceFailure implements Exception {
  const ResourceFailure(
    this.message, {
    this.partialReceipt,
    this.borderId,
    this.warningCodes = const [],
  });

  final String message;
  final ResourceMutationReceipt? partialReceipt;
  final String? borderId;
  final List<String> warningCodes;

  @override
  String toString() => message;
}
