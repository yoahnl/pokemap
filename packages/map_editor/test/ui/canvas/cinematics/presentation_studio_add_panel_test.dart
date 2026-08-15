import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_add_authoring_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_add_panel.dart';

void main() {
  testWidgets(
    'search and categories keep the target frozen until one explicit insertion',
    (tester) async {
      final project = _project();
      final gateway = _FakeGateway(
        media: <PresentationStudioMediaCatalogItem>[
          const PresentationStudioMediaCatalogItem(
            id: 'mountains',
            label: 'Montagnes',
            kind: ProjectMediaKind.image,
            availability: PresentationStudioMediaAvailability.ready,
            metadataLabel: 'PNG · 3840 × 2160',
          ),
          const PresentationStudioMediaCatalogItem(
            id: 'opening-music',
            label: 'Musique ouverture',
            kind: ProjectMediaKind.audio,
            availability: PresentationStudioMediaAvailability.ready,
            metadataLabel: 'OGG · 12 s',
            durationUs: 12000000,
          ),
        ],
      );
      final inserted = <PresentationStudioInsertionResult>[];

      await _pumpPanel(
        tester,
        gateway: gateway,
        project: project,
        playheadUs: 2750000,
        onInserted: inserted.add,
      );

      for (final label in <String>[
        'Visuel',
        'Texte',
        'Audio',
        'Vidéo',
        'Accessibilité',
        'Repères',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.enterText(
        find.byKey(const ValueKey<String>('presentation-add-search')),
        'mont',
      );
      await tester.pump();
      expect(find.text('Montagnes'), findsOneWidget);
      expect(find.text('Musique ouverture'), findsNothing);

      await tester.tap(find.text('Montagnes'));
      await tester.pump();
      expect(gateway.insertions, isEmpty);

      final confirm = find.byKey(
        const ValueKey<String>('presentation-add-confirm'),
      );
      await tester.tap(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(gateway.insertions, hasLength(1));
      expect(gateway.insertions.single.playheadUs, 2750000);
      expect(gateway.insertions.single.targetVisualFolderId, 'characters');
      expect(gateway.insertions.single.mediaId, 'mountains');
      expect(inserted, hasLength(1));
    },
  );

  testWidgets('unavailable media and duration conflict are explicit in text', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      media: <PresentationStudioMediaCatalogItem>[
        const PresentationStudioMediaCatalogItem(
          id: 'missing',
          label: 'Image manquante',
          kind: ProjectMediaKind.image,
          availability: PresentationStudioMediaAvailability.missing,
          metadataLabel: 'Fichier introuvable',
        ),
        const PresentationStudioMediaCatalogItem(
          id: 'corrupt',
          label: 'Image corrompue',
          kind: ProjectMediaKind.image,
          availability: PresentationStudioMediaAvailability.corrupt,
          metadataLabel: 'Réimportation requise',
        ),
        const PresentationStudioMediaCatalogItem(
          id: 'unsupported',
          label: 'Codec exotique',
          kind: ProjectMediaKind.image,
          availability: PresentationStudioMediaAvailability.unsupported,
          metadataLabel: 'Format non supporté',
        ),
        const PresentationStudioMediaCatalogItem(
          id: 'too-long',
          label: 'Plan très long',
          kind: ProjectMediaKind.image,
          availability: PresentationStudioMediaAvailability.ready,
          metadataLabel: 'PNG · 20 s',
          durationUs: 20000000,
        ),
      ],
    );

    await _pumpPanel(
      tester,
      gateway: gateway,
      project: _project(),
      playheadUs: 9000000,
      onInserted: (_) {},
    );

    expect(find.text('Fichier introuvable'), findsOneWidget);
    expect(find.text('Réimportation requise'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump();
    expect(find.text('Format non supporté'), findsOneWidget);

    await tester.tap(find.text('Plan très long'));
    await tester.pump();
    expect(find.textContaining('dépasse la durée restante'), findsOneWidget);
    expect(find.text('Ajuster à la durée restante'), findsOneWidget);
  });

  testWidgets('cancelled import ignores a late callback and creates no entry', (
    tester,
  ) async {
    final import = Completer<PresentationStudioMediaImportResult>();
    final gateway = _FakeGateway(media: const [], importCompleter: import);

    await _pumpPanel(
      tester,
      gateway: gateway,
      project: _project(),
      playheadUs: 0,
      onInserted: (_) {},
      picker: const _FakePicker(
        PresentationStudioPickedMedia(
          sourcePath: '/tmp/opening.png',
          label: 'opening.png',
        ),
      ),
    );

    await tester.tap(find.text('Importer un média'));
    await tester.pump();
    expect(find.text('Import en cours…'), findsOneWidget);

    await tester.tap(find.text('Annuler l’import'));
    import.complete(
      PresentationStudioMediaImportResult(
        manifest: _project(),
        media: const PresentationStudioMediaCatalogItem(
          id: 'late-media',
          label: 'Late media',
          kind: ProjectMediaKind.image,
          availability: PresentationStudioMediaAvailability.ready,
          metadataLabel: 'PNG',
        ),
        receiptId: 'late-receipt',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Late media'), findsNothing);
    expect(gateway.insertions, isEmpty);
  });

  testWidgets('catalog load failure exposes a retry then the empty state', (
    tester,
  ) async {
    final gateway = _FakeGateway(media: const [], loadFailures: 1);

    await _pumpPanel(
      tester,
      gateway: gateway,
      project: _project(),
      playheadUs: 0,
      onInserted: (_) {},
    );

    expect(find.text('Catalogue indisponible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(gateway.loadCalls, 2);
    expect(find.text('Aucun média dans cette catégorie'), findsOneWidget);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required _FakeGateway gateway,
  required ProjectManifest project,
  required int playheadUs,
  required ValueChanged<PresentationStudioInsertionResult> onInserted,
  PresentationStudioMediaPicker picker = const _FakePicker(null),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 800,
          child: PresentationStudioAddPanel(
            gateway: gateway,
            mediaPicker: picker,
            projectRootPath: '/project',
            expectedProject: project,
            asset: project.presentationCinematics.single,
            playheadUs: playheadUs,
            targetVisualFolderId: 'characters',
            onProjectChanged: (_) {},
            onInserted: onInserted,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _project() => ProjectManifest(
  name: 'Presentation add panel',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 10000000,
      visualFolders: <PresentationVisualFolder>[
        PresentationVisualFolder(id: 'characters', label: 'Characters'),
      ],
    ),
  ],
);

final class _FakeGateway implements PresentationStudioAddAuthoringGateway {
  _FakeGateway({
    required this.media,
    this.importCompleter,
    this.loadFailures = 0,
  });

  final List<PresentationStudioMediaCatalogItem> media;
  final Completer<PresentationStudioMediaImportResult>? importCompleter;
  final int loadFailures;
  final List<PresentationStudioInsertionRequest> insertions = [];
  int loadCalls = 0;

  @override
  Future<List<PresentationStudioMediaCatalogItem>> loadMedia(
    String projectRootPath,
  ) async {
    loadCalls += 1;
    if (loadCalls <= loadFailures) throw StateError('Catalogue hors ligne');
    return media;
  }

  @override
  Future<PresentationStudioMediaImportResult> importMedia(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationStudioMediaImportRequest request,
    required bool Function() isCancelled,
  }) => importCompleter!.future;

  @override
  Future<PresentationStudioInsertionResult> insert(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationStudioInsertionRequest request,
  }) async {
    insertions.add(request);
    return PresentationStudioInsertionResult(
      manifest: expectedProject,
      receiptId: 'insert-receipt',
      trackId: 'new-track',
      clipId: 'new-clip',
      layerId: 'new-layer',
    );
  }
}

final class _FakePicker implements PresentationStudioMediaPicker {
  const _FakePicker(this.result);

  final PresentationStudioPickedMedia? result;

  @override
  Future<PresentationStudioPickedMedia?> pick(
    PresentationStudioAddCategory category,
  ) async => result;
}
