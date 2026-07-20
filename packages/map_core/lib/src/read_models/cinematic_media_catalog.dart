import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_media_asset.dart';

enum CinematicMediaPathResolution { present, missing, forbidden }

enum CinematicMediaCatalogIssueKind {
  duplicateId,
  absolutePath,
  parentTraversal,
  missingFile,
  forbiddenPath,
  missingReference,
  typeMismatch,
}

@immutable
final class CinematicMediaCatalogIssue {
  const CinematicMediaCatalogIssue({
    required this.kind,
    required this.assetId,
    required this.message,
  });

  final CinematicMediaCatalogIssueKind kind;
  final String assetId;
  final String message;
}

@immutable
final class CinematicMediaResolution {
  CinematicMediaResolution({
    required this.asset,
    required List<CinematicMediaCatalogIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final CinematicMediaAsset? asset;
  final List<CinematicMediaCatalogIssue> issues;

  bool get isReady => asset != null && issues.isEmpty;
}

@immutable
final class CinematicMediaCatalog {
  CinematicMediaCatalog({
    required Map<String, List<CinematicMediaAsset>> assetsById,
    required List<CinematicMediaCatalogIssue> issues,
  })  : assetsById = Map.unmodifiable({
          for (final entry in assetsById.entries)
            entry.key: List<CinematicMediaAsset>.unmodifiable(entry.value),
        }),
        issues = List.unmodifiable(issues);

  final Map<String, List<CinematicMediaAsset>> assetsById;
  final List<CinematicMediaCatalogIssue> issues;

  CinematicMediaResolution resolve(
    String assetId, {
    CinematicMediaAssetKind? expectedKind,
  }) {
    final matches = assetsById[assetId] ?? const [];
    final localIssues = [
      for (final issue in issues)
        if (issue.assetId == assetId) issue,
    ];
    if (matches.isEmpty) {
      localIssues.add(CinematicMediaCatalogIssue(
        kind: CinematicMediaCatalogIssueKind.missingReference,
        assetId: assetId,
        message: 'Asset média absent du projet.',
      ));
      return CinematicMediaResolution(asset: null, issues: localIssues);
    }
    final asset = matches.length == 1 ? matches.single : null;
    if (asset != null && expectedKind != null && asset.kind != expectedKind) {
      localIssues.add(CinematicMediaCatalogIssue(
        kind: CinematicMediaCatalogIssueKind.typeMismatch,
        assetId: assetId,
        message:
            'Type ${asset.kind.name} incompatible avec ${expectedKind.name}.',
      ));
    }
    return CinematicMediaResolution(asset: asset, issues: localIssues);
  }
}

CinematicMediaCatalog buildCinematicMediaCatalog(
  Iterable<CinematicMediaAsset> assets, {
  required CinematicMediaPathResolution Function(String relativePath)
      resolvePath,
}) {
  final byId = <String, List<CinematicMediaAsset>>{};
  final issues = <CinematicMediaCatalogIssue>[];
  for (final asset in assets) {
    byId.putIfAbsent(asset.id, () => []).add(asset);
    final normalized = asset.relativePath.replaceAll('\\', '/');
    if (normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:/').hasMatch(normalized)) {
      issues.add(_issue(asset, CinematicMediaCatalogIssueKind.absolutePath,
          'Le chemin doit être relatif au projet.'));
      continue;
    }
    if (normalized.split('/').contains('..')) {
      issues.add(_issue(asset, CinematicMediaCatalogIssueKind.parentTraversal,
          'Le chemin ne peut pas sortir du projet.'));
      continue;
    }
    switch (resolvePath(normalized)) {
      case CinematicMediaPathResolution.present:
        break;
      case CinematicMediaPathResolution.missing:
        issues.add(_issue(asset, CinematicMediaCatalogIssueKind.missingFile,
            'Fichier média introuvable.'));
      case CinematicMediaPathResolution.forbidden:
        issues.add(_issue(asset, CinematicMediaCatalogIssueKind.forbiddenPath,
            'Chemin média interdit.'));
    }
  }
  for (final entry in byId.entries) {
    if (entry.value.length > 1) {
      issues.add(CinematicMediaCatalogIssue(
        kind: CinematicMediaCatalogIssueKind.duplicateId,
        assetId: entry.key,
        message: 'ID média dupliqué.',
      ));
    }
  }
  return CinematicMediaCatalog(assetsById: byId, issues: issues);
}

CinematicMediaCatalogIssue _issue(
  CinematicMediaAsset asset,
  CinematicMediaCatalogIssueKind kind,
  String message,
) =>
    CinematicMediaCatalogIssue(kind: kind, assetId: asset.id, message: message);
