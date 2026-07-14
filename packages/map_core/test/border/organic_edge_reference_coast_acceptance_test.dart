import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/organic_edge_reference_coast_fixture.dart';

void main() {
  test('reference coast has no blocking gap or ground overhang', () {
    final fixture = OrganicEdgeReferenceCoastFixture();
    final request = fixture.referenceCoastRequest();

    final first = resolveOrganicEdgeBorderWithEvidence(request);
    final second = resolveOrganicEdgeBorderWithEvidence(request);

    expect(second, first);
    expect(first.result.canApply, isTrue);
    expect(
      first.result.diagnostics.map((diagnostic) => diagnostic.code),
      isNot(contains('border.resolution.coverage_gap')),
    );
    expect(first.contours, hasLength(2));
    expect(
      first.contours.every(
        (contour) => !contour.coverage.hasExcessiveGap,
      ),
      isTrue,
    );

    final materialization = first.result.materialization!;
    final geometry = fixture.referenceCoastGeometry;
    expect(materialization.ground, isNotEmpty);
    expect(
      materialization.ground.every(
        (cell) => geometry.cells[cell.y * geometry.width + cell.x],
      ),
      isTrue,
    );
    expect(
      materialization.ground,
      resolveBorderGroundBand(
        region: geometry,
        ground: fixture.definition.ground!,
      ),
    );
    expect(
      materialization.receipt.outputFingerprint,
      second.result.materialization!.receipt.outputFingerprint,
    );
  });
}
