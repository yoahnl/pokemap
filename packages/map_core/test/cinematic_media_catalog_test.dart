import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('detects collisions forbidden paths and missing files', () {
    final catalog = buildCinematicMediaCatalog(
      [
        _asset('duplicate', 'audio/one.ogg'),
        _asset('duplicate', 'audio/two.ogg'),
        _asset('absolute', '/tmp/secret.ogg'),
        _asset('escape', '../outside.ogg'),
        _asset('missing', 'audio/missing.ogg'),
      ],
      resolvePath: (path) => path == 'audio/missing.ogg'
          ? CinematicMediaPathResolution.missing
          : CinematicMediaPathResolution.present,
    );

    expect(
        catalog.issues.map((issue) => issue.kind),
        containsAll([
          CinematicMediaCatalogIssueKind.duplicateId,
          CinematicMediaCatalogIssueKind.absolutePath,
          CinematicMediaCatalogIssueKind.parentTraversal,
          CinematicMediaCatalogIssueKind.missingFile,
        ]));
  });

  test('resolves by expected kind and explains incompatibility', () {
    final catalog = buildCinematicMediaCatalog(
      [_asset('wave', 'audio/wave.ogg')],
      resolvePath: (_) => CinematicMediaPathResolution.present,
    );

    expect(
      catalog
          .resolve('wave', expectedKind: CinematicMediaAssetKind.sound)
          .isReady,
      isTrue,
    );
    expect(
      catalog
          .resolve('wave', expectedKind: CinematicMediaAssetKind.music)
          .issues
          .single
          .kind,
      CinematicMediaCatalogIssueKind.typeMismatch,
    );
  });
}

CinematicMediaAsset _asset(String id, String path) => CinematicMediaAsset(
      id: id,
      label: id,
      kind: CinematicMediaAssetKind.sound,
      relativePath: path,
    );
