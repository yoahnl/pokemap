import 'dart:io';

import 'package:path/path.dart' as p;

import '../infrastructure/runtime_ui_image.dart';
import 'dialogue_portrait_resolver.dart';
import 'runtime_map_bundle.dart';

Future<RuntimeUiImageLease?> loadRuntimeTrainerBattleImage({
  required RuntimeMapBundle bundle,
  required String trainerId,
  DialoguePortraitResolver? portraitResolver,
  bool Function()? isCurrent,
}) async {
  final matches = bundle.manifest.trainers.where(
    (entry) => entry.id == trainerId,
  );
  if (matches.length != 1) return null;
  final trainer = matches.single;
  final root = bundle.projectRootDirectory;

  Future<RuntimeUiImageLease?> load(String absolutePath) async {
    if (isCurrent?.call() == false) return null;
    try {
      final canonicalRoot = await Directory(root).resolveSymbolicLinks();
      final resolved = await File(absolutePath).resolveSymbolicLinks();
      if (!p.isWithin(canonicalRoot, resolved)) return null;
      final lease = await loadRuntimeUiImageFromFilePath(
        resolved,
        resourceBudget: bundle.resourceBudget,
        isCurrent: isCurrent,
      );
      if (isCurrent?.call() == false) {
        lease.dispose();
        return null;
      }
      return lease;
    } on Object {
      return null;
    }
  }

  final artwork = trainer.battleSpriteRelativePath?.trim();
  if (artwork != null && artwork.isNotEmpty) {
    final lease = await load(p.normalize(p.join(root, artwork)));
    if (lease != null) return lease;
  }
  if (isCurrent?.call() == false) return null;
  final characterId = trainer.characterId?.trim();
  if (characterId == null || characterId.isEmpty) return null;
  final resolver =
      portraitResolver ??
      DialoguePortraitResolver(
        manifest: bundle.manifest,
        projectRootDirectory: root,
      );
  try {
    await resolver.ensureCatalogLoaded(characterIds: {characterId});
    if (isCurrent?.call() == false) return null;
    final portrait = resolver.resolve(
      characterId: characterId,
      portraitStateId: 'neutre',
    );
    return portrait == null ? null : await load(portrait.absoluteFilePath);
  } on Object {
    return null;
  }
}
