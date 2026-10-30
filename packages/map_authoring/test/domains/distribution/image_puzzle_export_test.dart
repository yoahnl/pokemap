import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final puzzle in [false, true]) {
    test(
        'export preserves puzzle media closure and conditional capability puzzle=$puzzle',
        () async {
      final qa = Directory(
          '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle-authoring');
      await qa.create(recursive: true);
      final root = await qa.createTemp('export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final original = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!))
              as Map<String, dynamic>);
      final definition = ImagePuzzleDefinition(
          puzzleId: 'mosaic',
          imageResourceId: 'mosaic-image',
          rows: 2,
          columns: 2);
      final scene = SceneAsset(
          id: 'puzzle',
          name: 'Puzzle',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'puzzle',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.openImagePuzzle(
                        definition: definition))),
            SceneNode(id: 'end', kind: SceneNodeKind.end)
          ], edges: [
            SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'puzzle',
                kind: SceneEdgeKind.defaultFlow),
            for (final port in ['solved', 'quit'])
              SceneEdge(
                  id: port,
                  fromNodeId: 'puzzle',
                  fromPortId: port,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted)
          ]));
      files['project/project.json'] = utf8.encode(jsonEncode(
          original.copyWith(scenes: puzzle ? [scene] : []).toJson()));
      final png = image.encodePng(image.Image(width: 8, height: 8));
      final asset = AssetRecord(
          id: 'source-image',
          logicalPath: 'assets/mosaic.png',
          artifact: ContentArtifactRef.fromBytes(png, mediaType: 'image/png'));
      files['project/$assetCatalogStorageKey'] =
          utf8.encode(jsonEncode(AssetCatalog(records: [
        ...AssetCatalog.fromJson(jsonDecode(
                    utf8.decode(files['project/$assetCatalogStorageKey']!))
                as Map<String, dynamic>)
            .records,
        asset
      ]).toJson()));
      files['project/${assetBlobStorageKey(asset.artifact)}'] = png;
      files['project/$projectMediaCatalogStorageKey'] =
          encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
        ProjectMediaAsset(
            id: 'mosaic-image',
            label: 'Mosaïque',
            kind: ProjectMediaKind.image,
            sourceAssetId: asset.id,
            provenance:
                ProjectMediaProvenance(source: 'Generated test fixture'),
            license: ProjectMediaLicense(identifier: 'CC0-1.0', name: 'CC0'),
            technicalMetadata: ProjectMediaTechnicalMetadata(
                mediaType: 'image/png',
                container: 'png',
                codec: 'png',
                sizeBytes: png.length,
                width: 8,
                height: 8))
      ]));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final before = await File('${root.path}/project.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.test.puzzle',
              gameVersion: '0.1.0',
              title: 'Puzzle',
              authorName: 'Fixture',
              defaultLocale: 'fr',
              supportedLocales: ['fr']),
          mode: GamePackageExportMode.localTest);
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains(SpatialGameplayCapabilities.imagePuzzleCapabilityId),
          puzzle);
      final projection = await RuntimeProjectProjectionBuilder().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.test.puzzle',
              gameVersion: '0.1.0',
              title: 'Puzzle',
              authorName: 'Fixture',
              defaultLocale: 'fr',
              supportedLocales: ['fr']));
      final media = decodeProjectMediaCatalogBytes(
          projection.payloadFiles['project/$projectMediaCatalogStorageKey']!);
      expect(media.find('mosaic-image') != null, puzzle);
      if (puzzle) {
        expect(
            projection
                .payloadFiles['project/${assetBlobStorageKey(asset.artifact)}'],
            png);
      }
      final current = AveluneRuntimeCompatibility.host();
      final old = GamePackageHostCompatibility(
          hubVersion: current.hubVersion,
          runtimeApiVersion: current.runtimeApiVersion,
          capabilities: {...current.capabilities}
            ..remove(SpatialGameplayCapabilities.imagePuzzleCapabilityId),
          supportedProjectFormats: current.supportedProjectFormats,
          currentProjectFormat: current.currentProjectFormat,
          currentProjectFormats: current.currentProjectFormats,
          supportedSaveFormats: current.supportedSaveFormats);
      final compatibility = const GamePackageCompatibilityEvaluator()
          .evaluate(result.manifest, old);
      expect(
          compatibility.decision,
          puzzle
              ? GamePackageCompatibilityDecision.reject
              : GamePackageCompatibilityDecision.accept);
      if (puzzle) {
        expect(compatibility.missingCapabilities,
            [SpatialGameplayCapabilities.imagePuzzleCapabilityId]);
      }
      expect(
          const GamePackageInspector()
              .inspect(result.packageBytes)
              .manifest
              .gameId,
          'games.test.puzzle');
      expect(await File('${root.path}/project.json').readAsBytes(), before);
    });
  }
}
