import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_layer_authoring_gateway.dart';

void main() {
  test('applies, rereads and undoes a canonical layer command', () async {
    final root = await Directory.systemTemp.createTemp(
      'presentation_layer_gateway_',
    );
    final manifestFile = File('${root.path}/project.json');
    final container = ProviderContainer();
    addTearDown(() async {
      await container.read(authoringMutationAdapterProvider).closeAll();
      await container.read(authoringQueryAdapterProvider).closeAll();
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });

    final manifest = ProjectManifest(
      name: 'Presentation layer gateway',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
          layers: <PresentationLayer>[
            PresentationLayer(id: 'foreground', label: 'Foreground', zIndex: 0),
          ],
        ),
      ],
    );
    await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
    final mutations = container.read(authoringMutationAdapterProvider);
    final queries = container.read(authoringQueryAdapterProvider);
    final gateway = CanonicalPresentationStudioLayerAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );

    final updated = await gateway.apply(
      root.path,
      expectedProject: manifest,
      actionId: 'presentationLayer.setVisibility',
      parameters: const <String, Object?>{
        'cinematicId': 'opening',
        'layerId': 'foreground',
        'visible': false,
      },
    );

    expect(
      updated.presentationCinematics.single.layers.single.visible,
      isFalse,
    );
    expect(
      _readManifest(
        manifestFile,
      ).presentationCinematics.single.layers.single.visible,
      isFalse,
    );
    final receipt = mutations.lastAppliedReceipt!;
    expect(receipt.actionId, 'presentationLayer.setVisibility');

    await mutations.undo(
      root.path,
      entryId: receipt.receiptId,
      idempotencyKey: 'presentation_layer_gateway_undo',
    );
    final restored = (await queries.open(root.path)).manifest;

    expect(
      restored.presentationCinematics.single.layers.single.visible,
      isTrue,
    );
    expect(
      _readManifest(
        manifestFile,
      ).presentationCinematics.single.layers.single.visible,
      isTrue,
    );
  });
}

ProjectManifest _readManifest(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded as Map));
}
