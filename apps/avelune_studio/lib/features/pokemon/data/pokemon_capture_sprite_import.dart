import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_authoring/map_authoring.dart'
    show AssetCatalog, assetCatalogResourceIdentity, ContentArtifactRef;
import 'package:map_authoring/map_authoring_local.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';

final class PokemonCaptureSpriteImport {
  const PokemonCaptureSpriteImport({
    required this.session,
    required this.mapAdapter,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  Future<String> run({
    required String sourcePath,
    required String itemId,
    bool Function()? shouldContinue,
  }) => mapAdapter.withResourceMutation(
    () => _run(
      sourcePath: sourcePath,
      itemId: itemId,
      shouldContinue: shouldContinue,
    ),
  );

  Future<String> _run({
    required String sourcePath,
    required String itemId,
    bool Function()? shouldContinue,
  }) async {
    void requireCurrent() {
      if (shouldContinue?.call() == false) {
        throw StateError('La fiche a été fermée. Import annulé.');
      }
    }

    requireCurrent();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await opener.openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [session.directoryPath],
      maximumArtifactBytes: 16 * 1024 * 1024,
    );
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final snapshot = await snapshots.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      if (!snapshot.manifest.pokemon.enabled || snapshot.itemCatalog == null) {
        throw StateError('Catalogue d’objets indisponible.');
      }
      if (!snapshot.itemCatalog!.entries.any(
        (item) => item.id == itemId && item.capture != null,
      )) {
        throw StateError('Cet objet ne possède pas de capacité de capture.');
      }
      await artifacts.authorizeSourceFile(sourcePath);
      final staged = await api.stageArtifactFile(
        sourcePath: sourcePath,
        declaredMediaType: 'image/png',
      );
      final bytes = Uint8List.fromList(
        await artifacts.read(staged.reference.handle),
      );
      await _validatePng(bytes);
      final digest = staged.reference.hexDigest;
      final path = 'data/pokemon/assets/items/capture/$digest.png';
      final catalogBytes = snapshot.findResourceBytes(
        assetCatalogResourceIdentity,
      );
      final catalog = catalogBytes == null
          ? AssetCatalog()
          : AssetCatalog.fromJson(
              jsonDecode(utf8.decode(catalogBytes)) as Map<String, dynamic>,
            );
      final existing = catalog.findByLogicalPath(path);
      if (existing != null) {
        final currentBytes = await reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: path,
        );
        if (existing.artifact.digest != staged.reference.digest ||
            ContentArtifactRef.fromBytes(
                  currentBytes,
                  mediaType: 'image/png',
                ) !=
                staged.reference) {
          throw StateError(
            'La ressource existante a changé. Aucun remplacement effectué.',
          );
        }
        requireCurrent();
        return path;
      }
      final operation =
          'capture_sprite_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      requireCurrent();
      final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'asset.import_batch',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: {
            'entries': [
              {
                'assetId': 'capture-sprite-$digest',
                'logicalPath': path,
                'artifactHandle': staged.reference.handle,
                'usages': ['item:$itemId'],
                'tags': ['item-capture-animation'],
              },
            ],
          },
        ),
      );
      if (!plan.applicable) {
        throw StateError('Import non applicable : ${plan.nonApplicableReason}');
      }
      requireCurrent();
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: plan.planId,
          operationId: operation,
        );
      } on Object catch (failure) {
        try {
          await api.recoverMutation(
            opened.projectHandle,
            operationId: operation,
          );
        } on Object {
          throw StateError(
            'Import interrompu ; journal $operation conservé : $failure',
          );
        }
        rethrow;
      }
      return path;
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<void> _validatePng(Uint8List bytes) async {
    if (bytes.length < 33 ||
        bytes[0] != 137 ||
        bytes[1] != 80 ||
        bytes[2] != 78 ||
        bytes[3] != 71 ||
        ByteData.sublistView(bytes).getUint32(16) != 64 ||
        ByteData.sublistView(bytes).getUint32(20) != 2048) {
      throw const FormatException(
        'Choisissez une planche PNG de 64 × 2048 pixels (32 images de 64 × 64).',
      );
    }
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      image = (await codec.getNextFrame()).image;
      if (image.width != 64 || image.height != 2048) {
        throw const FormatException('Dimensions de la planche invalides.');
      }
    } on Object {
      throw const FormatException('Le PNG ne se décode pas correctement.');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
