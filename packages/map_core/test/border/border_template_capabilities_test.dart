import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('stone-chain capabilities require V3 grid-edge strokes', () {
    const template = BorderBlueprintTemplate.stoneChainLine;

    expect(borderTemplateUsesStrokeGeometry(template), isTrue);
    expect(borderTemplateSupportsLineSide(template), isTrue);
    expect(
      borderTemplateStrokeAlignment(template),
      BorderStrokeAlignment.gridEdges,
    );
    expect(
      minimumBorderCatalogFormatVersionForTemplate(template),
      ProjectBorderCatalog.formatVersionV3,
    );
    expect(borderTemplateRequiresInvertedCanonicalGallery(template), isTrue);
  });

  test('historical template capabilities remain unchanged', () {
    expect(
      borderTemplateUsesStrokeGeometry(BorderBlueprintTemplate.organicEdge),
      isFalse,
    );
    expect(
      borderTemplateUsesStrokeGeometry(BorderBlueprintTemplate.masonryLine),
      isTrue,
    );
    expect(
      borderTemplateSupportsLineSide(BorderBlueprintTemplate.connectedLine),
      isTrue,
    );
    expect(
      borderTemplateSupportsLineSide(BorderBlueprintTemplate.masonryLine),
      isTrue,
    );
    expect(
      borderTemplateStrokeAlignment(BorderBlueprintTemplate.connectedLine),
      BorderStrokeAlignment.cellCenters,
    );
    expect(
      minimumBorderCatalogFormatVersionForTemplate(
        BorderBlueprintTemplate.connectedLine,
      ),
      ProjectBorderCatalog.formatVersionV2,
    );
    expect(
      borderTemplateRequiresInvertedCanonicalGallery(
        BorderBlueprintTemplate.connectedLine,
      ),
      isTrue,
    );
    expect(
      borderTemplateRequiresInvertedCanonicalGallery(
        BorderBlueprintTemplate.masonryLine,
      ),
      isFalse,
    );
  });
}
