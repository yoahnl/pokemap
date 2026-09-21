import 'dart:convert';
import 'package:map_core/map_core.dart';
import '../assets/asset_store.dart';
import '../assets/project_media_store.dart';
import '../../workspace/project_snapshot.dart';
import '../../support/authoring_fingerprint.dart';
import '../../ports/artifact_store.dart';

void validatePresentationPublicationBase(
    ProjectSnapshot snapshot, String id, Map<String, Object?> p) {
  final project = snapshot.manifest;
  if (project.version != ProjectVersion.v7) {
    throw StateError('Les présentations nécessitent un projet v7.');
  }
  final current =
      project.presentationCinematics.where((a) => a.id == id).firstOrNull;
  final entry = project.cinematicLibraryCatalog
      .entryFor(CinematicLibraryFamily.presentation, id);
  if (!_same(current == null ? null : encodePresentationCinematicAsset(current),
          p['expectedCinematic']) ||
      !_same(entry?.toJson(), p['expectedEntry'])) {
    throw StateError(
        'La présentation ou son classement a changé. Le brouillon est conservé.');
  }
  final link = p['link'];
  if (link != null) {
    if (link is! Map ||
        link.keys.any((k) => !const {
              'baseScene',
              'scene',
              'nodeId',
              'targetNodeId'
            }.contains(k))) {
      throw ArgumentError('Invalid Presentation Scene link.');
    }
    final scene =
        SceneAsset.fromJson(Map<String, dynamic>.from(link['scene'] as Map));
    final existing = project.scenes.where((s) => s.id == scene.id).firstOrNull;
    if (existing == null || !_same(existing.toJson(), link['baseScene'])) {
      throw StateError(
          'La scène a changé. Le brouillon de présentation est conservé.');
    }
  }
  final mediaBytes =
      snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
  final media = mediaBytes == null
      ? ProjectMediaCatalog()
      : decodeProjectMediaCatalogBytes(mediaBytes);
  final assetsBytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  final assets = assetsBytes == null
      ? null
      : AssetCatalog.fromJson(Map<String, dynamic>.from(
          jsonDecode(utf8.decode(assetsBytes)) as Map));
  for (final raw in p['expectedMedia'] as List? ?? const []) {
    final expected = Map<String, Object?>.from(raw as Map);
    final id = (expected['media'] as Map)['id'] as String;
    final item = media.find(id);
    final source = item == null
        ? null
        : assets?.records.where((a) => a.id == item.sourceAssetId).firstOrNull;
    if (!_same(item?.toJson(), expected['media']) ||
        !_same(source?.toJson(), expected['asset'])) {
      throw StateError(
          'Une source média a changé. Actualisez les ressources avant de publier.');
    }
  }
}

bool _same(Object? a, Object? b) =>
    computeAuthoringJsonFingerprint(a, logicalName: 'baseline') ==
    computeAuthoringJsonFingerprint(b, logicalName: 'baseline');

bool presentationImportAlreadyPublished(
    ProjectSnapshot snapshot,
    Map<String, Object?> parameters,
    Object? expected,
    ArtifactStore artifacts) {
  final bytes = snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
  final media = bytes == null
      ? null
      : decodeProjectMediaCatalogBytes(bytes)
          .find(parameters['mediaId'] as String);
  if (media == null) return false;
  final assetBytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  final assets = assetBytes == null
      ? AssetCatalog()
      : AssetCatalog.fromJson(Map<String, dynamic>.from(
          jsonDecode(utf8.decode(assetBytes)) as Map));
  final source = assets.find(media.sourceAssetId);
  final staged = artifacts.inspect(parameters['artifactHandle'] as String);
  if (expected == null ||
      !_same(media.toJson(), expected) ||
      staged == null ||
      source?.artifact.digest != staged.digest ||
      source?.artifact.byteLength != staged.byteLength) {
    throw StateError('Le média partagé a changé depuis sa préparation.');
  }
  return true;
}
