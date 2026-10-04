import 'package:flutter/services.dart';
import 'package:map_authoring/map_authoring_local.dart';

final class StudioProjectItemIcons {
  StudioProjectItemIcons({AssetBundle? bundle}) : _bundle = bundle;

  static final shared = StudioProjectItemIcons();
  final AssetBundle? _bundle;
  Future<ProjectItemIconPack>? _pack;
  Future<ProjectCaptureSpritePack>? _capturePack;

  Future<void> prepare(
    String projectRoot, {
    bool Function()? shouldContinue,
  }) async {
    await provisionProjectItemIcons(
      projectPath: projectRoot,
      loadPack: _loadPack,
      shouldContinue: shouldContinue,
    );
    await provisionProjectCaptureSprites(
      projectPath: projectRoot,
      loadPack: _loadCapturePack,
      shouldContinue: shouldContinue,
    );
  }

  Future<ProjectCaptureSpritePack> _loadCapturePack() async {
    try {
      return await (_capturePack ??= _readCapturePack());
    } on Object {
      _capturePack = null;
      rethrow;
    }
  }

  Future<ProjectCaptureSpritePack> _readCapturePack() async {
    final bundle = _bundle ?? rootBundle;
    final manifest = await bundle.load(
      'assets/pokemon/capture_sprites/manifest.json',
    );
    final archive = await bundle.load(
      'assets/pokemon/capture_sprites/sprites.zip',
    );
    return ProjectCaptureSpritePack(
      manifestBytes: manifest.buffer.asUint8List(
        manifest.offsetInBytes,
        manifest.lengthInBytes,
      ),
      archiveBytes: archive.buffer.asUint8List(
        archive.offsetInBytes,
        archive.lengthInBytes,
      ),
    );
  }

  Future<ProjectItemIconPack> _loadPack() async {
    try {
      return await (_pack ??= _readPack());
    } on Object {
      _pack = null;
      rethrow;
    }
  }

  Future<ProjectItemIconPack> _readPack() async {
    final bundle = _bundle ?? rootBundle;
    final manifest = await bundle.load(
      'assets/pokemon/item_icons/manifest.json',
    );
    final archive = await bundle.load('assets/pokemon/item_icons/icons.zip');
    return ProjectItemIconPack(
      manifestBytes: manifest.buffer.asUint8List(
        manifest.offsetInBytes,
        manifest.lengthInBytes,
      ),
      archiveBytes: archive.buffer.asUint8List(
        archive.offsetInBytes,
        archive.lengthInBytes,
      ),
    );
  }
}
