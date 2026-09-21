import 'dart:convert';
import 'dart:math';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;
import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/presentation_port.dart';
import 'local_presentation_connection.dart';
import 'local_presentation_projection.dart';
part 'local_presentation_media.dart';
part 'local_presentation_publication.dart';

class LocalPresentationAdapter implements PresentationPort {
  LocalPresentationAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  }) : artifacts = LocalArtifactStore(
         allowedSourceRoots: [session.directoryPath],
         maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
       );
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;
  final LocalArtifactStore artifacts;
  @override
  Future<PresentationPublicationReceipt> publish({
    required PresentationCinematicAsset asset,
    required PresentationSourceSnapshot? base,
    String? folderId,
    bool changeFolder = false,
    PresentationSceneLink? link,
    List<PresentationStagedMedia> imports = const [],
    List<Map<String, Object?>> mediaBaselines = const [],
  }) => _publish(
    asset: asset,
    base: base,
    folderId: folderId,
    changeFolder: changeFolder,
    link: link,
    imports: imports,
    mediaBaselines: mediaBaselines,
  );
  @override
  Future<PresentationPublicationReceipt> createFolder({
    required String id,
    required String name,
    String? parentFolderId,
  }) => _createFolder(id: id, name: name, parentFolderId: parentFolderId);
  @override
  Future<PresentationPublicationReceipt> delete(
    PresentationSourceSnapshot base,
  ) => _delete(base);
  @override
  Future<PresentationPublicationReceipt> setArchived(
    PresentationSourceSnapshot base,
    bool archived,
  ) => _setArchived(base, archived);
  @override
  Future<PresentationStagedMedia> stageMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  }) => _stageMedia(sourcePath: sourcePath, label: label, kind: kind);
  @override
  Future<void> releaseMedia(PresentationStagedMedia media) =>
      _releaseMedia(media);
  @override
  Future<PresentationSourceSnapshot> load(String id) =>
      mapAdapter.withResourceMutation(() async {
        await mapAdapter.resourceBaseline(session, refreshCatalog: true);
        final connection = await LocalPresentationConnection.open(
          session,
          artifacts,
          faultInjector,
        );
        try {
          final snapshot = await connection.read();
          return _source(snapshot, id) ??
              (throw const PresentationFailure(
                'Cette présentation est absente du projet.',
              ));
        } finally {
          await connection.close();
        }
      });
  @override
  Future<PresentationDraftProjection> prepare(ProjectManifest project) =>
      mapAdapter.withResourceMutation(() async {
        final connection = await LocalPresentationConnection.open(
          session,
          artifacts,
          faultInjector,
        );
        try {
          final snapshot = await connection.read();
          if (snapshot.manifest.version != ProjectVersion.v7) {
            throw const PresentationFailure(
              'Les présentations nécessitent un projet v7.',
            );
          }
          return LocalPresentationProjection(snapshot, project);
        } finally {
          await connection.close();
        }
      });
  PresentationSourceSnapshot? _source(ProjectSnapshot snapshot, String id) {
    final asset = snapshot.manifest.presentationCinematics
        .where((a) => a.id == id)
        .firstOrNull;
    if (asset == null) return null;
    if (snapshot.manifest.version != ProjectVersion.v7) {
      throw const PresentationFailure(
        'Les présentations nécessitent un projet v7.',
      );
    }
    final projection = LocalPresentationProjection(snapshot, snapshot.manifest);
    final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assets = bytes == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
          );
    return PresentationSourceSnapshot(
      asset: asset,
      revision: snapshot.revision,
      projection: projection,
      entry: snapshot.manifest.cinematicLibraryCatalog.entryFor(
        CinematicLibraryFamily.presentation,
        id,
      ),
      mediaBaselines: [
        for (final media in projection.mediaCatalog.entries)
          {
            'media': media.toJson(),
            'asset': assets.find(media.sourceAssetId)?.toJson(),
          },
      ],
    );
  }

  String _identity() =>
      'presentation_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
}
