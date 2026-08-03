import 'dart:collection';

import 'package:map_core/map_core.dart';

enum SmartTileVisibleFormStatus {
  covered,
  generated,
  fallback,
  ambiguous,
  missing;

  bool get isBlocking =>
      this == SmartTileVisibleFormStatus.ambiguous ||
      this == SmartTileVisibleFormStatus.missing;
}

SmartTileVisibleFormStatus smartTileVisibleFormStatus(
  SmartTileCoverageStatus status,
) =>
    switch (status) {
      SmartTileCoverageStatus.exact => SmartTileVisibleFormStatus.covered,
      SmartTileCoverageStatus.transformed =>
        SmartTileVisibleFormStatus.generated,
      SmartTileCoverageStatus.fallback => SmartTileVisibleFormStatus.fallback,
      SmartTileCoverageStatus.ambiguous => SmartTileVisibleFormStatus.ambiguous,
      SmartTileCoverageStatus.missing ||
      SmartTileCoverageStatus.noCandidate ||
      SmartTileCoverageStatus.missingVisualSource ||
      SmartTileCoverageStatus.outOfAtlasGrid =>
        SmartTileVisibleFormStatus.missing,
    };

final class SmartTileFormReadModel {
  SmartTileFormReadModel({
    required this.mask,
    required this.label,
    required this.description,
    required this.status,
    required List<SmartTileCandidate> candidates,
  }) : candidates = List<SmartTileCandidate>.unmodifiable(candidates);

  final int mask;
  final String label;
  final String description;
  final SmartTileVisibleFormStatus status;
  final List<SmartTileCandidate> candidates;

  String get key => 'form-$mask';
  int get variantCount => candidates.length;
}

List<SmartTileFormReadModel> projectSmartTileForms({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required Iterable<ProjectSmartTileAtlas> atlases,
  required Iterable<ProjectSmartTileAnimation> animations,
}) {
  final report = analyzeSmartTileCoverage(
    preset: preset,
    materials: materials,
    atlases: atlases,
    animations: animations,
  );
  final candidatesByMask = <int, List<SmartTileCandidate>>{};
  for (final rule in preset.rules) {
    final mask = smartTileMaskForSignature(
      rule.signature,
      topology: preset.topology,
    );
    if (mask == null) continue;
    candidatesByMask.putIfAbsent(mask, () => <SmartTileCandidate>[]).addAll(
          rule.candidates,
        );
  }
  final masks = <int>{
    ...smartTileCanonicalMasks(preset.templateHint),
    ...candidatesByMask.keys,
  };
  if (masks.isEmpty) masks.addAll(_canonicalMasksForTopology(preset.topology));
  final sortedMasks = masks.toList()..sort();
  final statusesByMask = <int, SmartTileVisibleFormStatus>{};
  for (final coverageCase in report.cases) {
    final mask = _maskFromCoverageCase(coverageCase);
    if (mask == null || !masks.contains(mask)) continue;
    final visible = smartTileVisibleFormStatus(coverageCase.status);
    statusesByMask.update(
      mask,
      (current) => _moreSevereStatus(current, visible),
      ifAbsent: () => visible,
    );
  }

  return UnmodifiableListView<SmartTileFormReadModel>(
    <SmartTileFormReadModel>[
      for (final mask in sortedMasks)
        SmartTileFormReadModel(
          mask: mask,
          label: smartTileFormHumanLabel(mask, preset.topology),
          description: _formDescription(mask, preset.topology),
          status: statusesByMask[mask] ??
              ((candidatesByMask[mask]?.isNotEmpty ?? false)
                  ? SmartTileVisibleFormStatus.covered
                  : SmartTileVisibleFormStatus.missing),
          candidates: candidatesByMask[mask] ?? const <SmartTileCandidate>[],
        ),
    ],
  );
}

List<SmartTileFormReadModel> smartTileFormsForAtlasFrame({
  required Iterable<SmartTileFormReadModel> forms,
  required String atlasId,
  required int column,
  required int row,
}) =>
    List<SmartTileFormReadModel>.unmodifiable(
      forms.where(
        (form) => form.candidates.any(
          (candidate) => candidate.parts.any(
            (part) => switch (part.source) {
              SmartTileFrameSource(:final frame) => frame.atlasId == atlasId &&
                  frame.column == column &&
                  frame.row == row,
              SmartTileAnimationSource() => false,
            },
          ),
        ),
      ),
    );

List<int> _canonicalMasksForTopology(SmartTileTopology topology) =>
    switch (topology) {
      SmartTileTopology.uniform => const <int>[0],
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.wangEdge4 =>
        List<int>.generate(16, (index) => index, growable: false),
      SmartTileTopology.wangCorner4 =>
        List<int>.generate(16, (index) => index << 4, growable: false),
      SmartTileTopology.blob8 => smartTileCanonicalMasks(
          SmartTileTemplateHint.blob47,
        ),
      SmartTileTopology.wang8 => smartTileCanonicalMasks(
          SmartTileTemplateHint.mixed256,
        ),
    };

int? _maskFromCoverageCase(SmartTileCoverageCase coverageCase) {
  final marker = coverageCase.id.lastIndexOf('mask_');
  if (marker < 0) return null;
  return int.tryParse(
    coverageCase.id.substring(marker + 'mask_'.length),
    radix: 16,
  );
}

SmartTileVisibleFormStatus _moreSevereStatus(
  SmartTileVisibleFormStatus left,
  SmartTileVisibleFormStatus right,
) =>
    _statusSeverity(left) >= _statusSeverity(right) ? left : right;

int _statusSeverity(SmartTileVisibleFormStatus status) => switch (status) {
      SmartTileVisibleFormStatus.covered => 0,
      SmartTileVisibleFormStatus.generated => 1,
      SmartTileVisibleFormStatus.fallback => 2,
      SmartTileVisibleFormStatus.ambiguous => 3,
      SmartTileVisibleFormStatus.missing => 4,
    };

String smartTileFormHumanLabel(int mask, SmartTileTopology topology) {
  if (topology == SmartTileTopology.uniform) return 'Surface continue';
  final cardinal = <String>[
    if (mask & smartTileNorthBit != 0) 'nord',
    if (mask & smartTileEastBit != 0) 'est',
    if (mask & smartTileSouthBit != 0) 'sud',
    if (mask & smartTileWestBit != 0) 'ouest',
  ];
  final corners = <String>[
    if (mask & smartTileNorthWestBit != 0) 'nord-ouest',
    if (mask & smartTileNorthEastBit != 0) 'nord-est',
    if (mask & smartTileSouthEastBit != 0) 'sud-est',
    if (mask & smartTileSouthWestBit != 0) 'sud-ouest',
  ];
  if (topology == SmartTileTopology.wangCorner4) {
    return corners.isEmpty
        ? 'Aucun coin raccordé'
        : corners.length == 4
            ? 'Tous les coins raccordés'
            : 'Coins ${corners.join(' et ')}';
  }
  if (cardinal.isEmpty) return 'Îlot isolé';
  if (cardinal.length == 4 && corners.length == 4) return 'Centre plein';
  if (cardinal.length == 4) return 'Croisement central';
  if (cardinal.length == 1) return 'Extrémité ${cardinal.single}';
  if (cardinal.length == 2) {
    if (cardinal.contains('nord') && cardinal.contains('sud')) {
      return 'Segment vertical';
    }
    if (cardinal.contains('est') && cardinal.contains('ouest')) {
      return 'Segment horizontal';
    }
    return 'Virage ${cardinal.join('-')}';
  }
  if (cardinal.length == 3) {
    final missing = const <String>{'nord', 'est', 'sud', 'ouest'}
        .difference(cardinal.toSet())
        .single;
    return 'Jonction sans $missing';
  }
  return 'Contour ${cardinal.join('-')}';
}

String _formDescription(int mask, SmartTileTopology topology) {
  if (topology == SmartTileTopology.uniform) {
    return 'La même matière occupe toute la cellule.';
  }
  final connections = <String>[
    if (mask & smartTileNorthBit != 0) 'bord nord',
    if (mask & smartTileEastBit != 0) 'bord est',
    if (mask & smartTileSouthBit != 0) 'bord sud',
    if (mask & smartTileWestBit != 0) 'bord ouest',
    if (mask & smartTileNorthWestBit != 0) 'coin nord-ouest',
    if (mask & smartTileNorthEastBit != 0) 'coin nord-est',
    if (mask & smartTileSouthEastBit != 0) 'coin sud-est',
    if (mask & smartTileSouthWestBit != 0) 'coin sud-ouest',
  ];
  if (connections.isEmpty) return 'Aucun voisin de même matière.';
  return 'Raccordé par ${connections.join(', ')}.';
}
