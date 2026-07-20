import '../models/border_catalog.dart';
import '../models/border_value_objects.dart';

bool borderTemplateUsesStrokeGeometry(BorderBlueprintTemplate template) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => false,
      BorderBlueprintTemplate.masonryLine ||
      BorderBlueprintTemplate.postAndRailLine ||
      BorderBlueprintTemplate.connectedLine ||
      BorderBlueprintTemplate.stoneChainLine =>
        true,
    };

bool borderTemplateSupportsLineSide(BorderBlueprintTemplate template) =>
    switch (template) {
      BorderBlueprintTemplate.masonryLine ||
      BorderBlueprintTemplate.connectedLine ||
      BorderBlueprintTemplate.stoneChainLine =>
        true,
      _ => false,
    };

/// Whether publication must prove the template on both visual sides.
///
/// This is intentionally narrower than [borderTemplateSupportsLineSide]:
/// masonry supports side authoring, but its historical canonical gallery does
/// not require a second resolved sample.
bool borderTemplateRequiresInvertedCanonicalGallery(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.connectedLine ||
      BorderBlueprintTemplate.stoneChainLine =>
        true,
      _ => false,
    };

/// Exact roles that have no alternative-role substitute at publication.
///
/// Organic and masonry structure accept a role family, so they deliberately
/// return no exact role here. A two-tier stone chain adds the face row to the
/// historical lip requirement.
Set<BorderPrimitiveRole> borderTemplateRequiredPrimitiveRoles({
  required BorderBlueprintTemplate template,
  required int depthRows,
}) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge ||
      BorderBlueprintTemplate.masonryLine =>
        const <BorderPrimitiveRole>{},
      BorderBlueprintTemplate.postAndRailLine => const <BorderPrimitiveRole>{
          BorderPrimitiveRole.post,
          BorderPrimitiveRole.span,
        },
      BorderBlueprintTemplate.connectedLine => const <BorderPrimitiveRole>{
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
          BorderPrimitiveRole.lineCorner,
        },
      BorderBlueprintTemplate.stoneChainLine when depthRows == 2 =>
        const <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
        },
      BorderBlueprintTemplate.stoneChainLine => const <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge
        },
    };

bool borderTemplateRequiresTwoTierStoneChainEvidence({
  required BorderBlueprintTemplate template,
  required int depthRows,
}) =>
    template == BorderBlueprintTemplate.stoneChainLine && depthRows == 2;

BorderStrokeAlignment borderTemplateStrokeAlignment(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.stoneChainLine => BorderStrokeAlignment.gridEdges,
      _ => BorderStrokeAlignment.cellCenters,
    };

int minimumBorderCatalogFormatVersionForTemplate(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.stoneChainLine =>
        ProjectBorderCatalog.formatVersionV3,
      BorderBlueprintTemplate.connectedLine =>
        ProjectBorderCatalog.formatVersionV2,
      _ => ProjectBorderCatalog.formatVersionV1,
    };
