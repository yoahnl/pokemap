import 'dart:convert';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import '../domain/presentation_port.dart';

class LocalPresentationProjection implements PresentationDraftProjection {
  LocalPresentationProjection(this.snapshot, ProjectManifest project) {
    _draft = PresentationCinematicDraft.fromSnapshot(
      snapshot,
      expectedProject: project,
      allowProjectedProject: true,
    );
    final bytes = snapshot.findResourceBytes(
      projectMediaCatalogResourceIdentity,
    );
    _media = bytes == null
        ? ProjectMediaCatalog()
        : decodeProjectMediaCatalogBytes(bytes);
  }
  ProjectSnapshot snapshot;
  late PresentationCinematicDraft _draft;
  late ProjectMediaCatalog _media;
  int _sequence = 0;
  @override
  ProjectManifest get manifest => _draft.manifest;
  @override
  ProjectMediaCatalog get mediaCatalog => _media;
  @override
  List<Map<String, Object?>> get mediaBaselines {
    final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assets = bytes == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
          );
    final mediaBytes = snapshot.findResourceBytes(
      projectMediaCatalogResourceIdentity,
    );
    final entries = mediaBytes == null
        ? <ProjectMediaAsset>[]
        : decodeProjectMediaCatalogBytes(mediaBytes).entries;
    return [
      for (final media in entries)
        {
          'media': media.toJson(),
          'asset': assets.find(media.sourceAssetId)?.toJson(),
        },
    ];
  }

  @override
  ProjectManifest apply(PresentationCommand command) => _draft.apply(
    actionId: command.actionId,
    parameters: command.parameters,
    operationId: 'presentation_edit_${++_sequence}',
  );
  @override
  void adopt(ProjectManifest manifest) {
    _draft.adopt(manifest);
  }

  @override
  void includeMedia(List<PresentationStagedMedia> imports) {
    final original = snapshot.findResourceBytes(
      projectMediaCatalogResourceIdentity,
    );
    final entries = original == null
        ? <ProjectMediaAsset>[]
        : decodeProjectMediaCatalogBytes(original).entries;
    _media = ProjectMediaCatalog(
      entries: <String, ProjectMediaAsset>{
        for (final media in entries) media.id: media,
        for (final item in imports) item.media.id: item.media,
      }.values,
    );
    final after = encodeProjectMediaCatalogBytes(_media);
    if (original != null &&
        narrativeEventBytesFingerprint(original) ==
            narrativeEventBytesFingerprint(after)) {
      return;
    }
    final projected = projectPresentationPublicationSnapshot(
      snapshot,
      manifest: manifest,
      changes: [
        AuthoringResourceChange(
          resource: AuthoringResourceRef(
            kind: 'presentationMediaCatalog',
            id: 'project',
          ),
          storageKey: projectMediaCatalogStorageKey,
          beforeBytes: original,
          afterBytes: after,
        ),
      ],
    );
    _draft = PresentationCinematicDraft.fromSnapshot(
      projected,
      expectedProject: manifest,
      allowProjectedProject: true,
    );
  }

  @override
  PresentationCinematicAsset instantiate({
    required String id,
    required String title,
    required String templateId,
    required int durationUs,
  }) {
    if (manifest.version != ProjectVersion.v7) {
      throw const PresentationFailure(
        'Les présentations nécessitent un projet v7.',
      );
    }
    final template = PresentationCinematicTemplateCatalog.canonical().require(
      templateId,
      version: 1,
    );
    final asset = instantiatePresentationCinematicTemplate(
      template,
      cinematicId: id,
      title: title,
      description: null,
    );
    final encoded = encodePresentationCinematicAsset(asset)
      ..['durationUs'] = durationUs;
    return decodePresentationCinematicAsset(encoded);
  }
}
