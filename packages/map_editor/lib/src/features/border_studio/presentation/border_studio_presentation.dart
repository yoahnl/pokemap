import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

String borderTemplateLabel(BorderBlueprintTemplate template) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => 'Côte organique',
      BorderBlueprintTemplate.masonryLine => 'Muret maçonné',
      BorderBlueprintTemplate.postAndRailLine => 'Clôture poteaux-traverses',
      BorderBlueprintTemplate.connectedLine => 'Ligne connectée',
    };

String borderTemplateDescription(BorderBlueprintTemplate template) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge =>
        'Falaises, plages, rives et contours naturellement irréguliers.',
      BorderBlueprintTemplate.masonryLine =>
        'Murets et remparts dessinés ensuite comme une ligne dans World Maps.',
      BorderBlueprintTemplate.postAndRailLine =>
        'Clôtures avec poteaux, traverses et futures ouvertures.',
      BorderBlueprintTemplate.connectedLine =>
        'Falaises, murs et bordures libres assemblés sur un tracé cardinal.',
    };

String borderRoleLabel(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.structureLarge => 'Structure principale',
      BorderPrimitiveRole.structureMedium => 'Structure secondaire',
      BorderPrimitiveRole.filler => 'Remplissage',
      BorderPrimitiveRole.accent => 'Détail',
      BorderPrimitiveRole.post => 'Poteau',
      BorderPrimitiveRole.span => 'Traverse',
      BorderPrimitiveRole.surfacePatch => 'Finition intérieure',
      BorderPrimitiveRole.outerAccent => 'Bord extérieur',
      BorderPrimitiveRole.lineCap => 'Extrémité',
      BorderPrimitiveRole.lineStraight => 'Segment droit',
      BorderPrimitiveRole.lineCorner => 'Angle',
    };

List<BorderPrimitiveRole> orderedBorderRoles(
  Iterable<BorderPrimitiveRole> roles,
) {
  final allowed = roles.toSet();
  return <BorderPrimitiveRole>[
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    BorderPrimitiveRole.lineCorner,
    BorderPrimitiveRole.structureLarge,
    BorderPrimitiveRole.structureMedium,
    BorderPrimitiveRole.filler,
    BorderPrimitiveRole.post,
    BorderPrimitiveRole.span,
    BorderPrimitiveRole.surfacePatch,
    BorderPrimitiveRole.outerAccent,
    BorderPrimitiveRole.accent,
  ].where(allowed.contains).toList(growable: false);
}

List<String> unresolvedBorderRoleLabels(BorderBlueprintDraftDefinition draft) {
  final assigned = <BorderPrimitiveRole>{
    for (final primitive in draft.primitives)
      if (primitive.weight > 0) primitive.role,
  };
  switch (draft.template) {
    case BorderBlueprintTemplate.organicEdge:
    case BorderBlueprintTemplate.masonryLine:
      const structures = <BorderPrimitiveRole>{
        BorderPrimitiveRole.structureLarge,
        BorderPrimitiveRole.structureMedium,
        BorderPrimitiveRole.filler,
      };
      if (assigned.intersection(structures).isEmpty) {
        return const <String>['Structure de raccord'];
      }
      return const <String>[];
    case BorderBlueprintTemplate.postAndRailLine:
      return <String>[
        if (!assigned.contains(BorderPrimitiveRole.post)) 'Poteau',
        if (!assigned.contains(BorderPrimitiveRole.span)) 'Traverse',
      ];
    case BorderBlueprintTemplate.connectedLine:
      return <String>[
        if (!assigned.contains(BorderPrimitiveRole.lineCap)) 'Extrémité',
        if (!assigned.contains(BorderPrimitiveRole.lineStraight))
          'Segment droit',
        if (!assigned.contains(BorderPrimitiveRole.lineCorner)) 'Angle',
      ];
  }
}

bool isRequiredBorderRole(
  BorderBlueprintTemplate template,
  BorderPrimitiveRole role,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge ||
      BorderBlueprintTemplate.masonryLine =>
        role == BorderPrimitiveRole.structureLarge ||
            role == BorderPrimitiveRole.structureMedium ||
            role == BorderPrimitiveRole.filler,
      BorderBlueprintTemplate.postAndRailLine =>
        role == BorderPrimitiveRole.post || role == BorderPrimitiveRole.span,
      BorderBlueprintTemplate.connectedLine =>
        role == BorderPrimitiveRole.lineCap ||
            role == BorderPrimitiveRole.lineStraight ||
            role == BorderPrimitiveRole.lineCorner,
    };

class BorderStudioNotice extends StatelessWidget {
  const BorderStudioNotice({
    super.key,
    required this.title,
    required this.description,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String description;
  final PokeMapTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      liveRegion: tone == PokeMapTone.danger || tone == PokeMapTone.warning,
      label: '$title. $description',
      child: PokeMapCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PokeMapIconTile(icon: icon, tone: tone, size: 34, iconSize: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BorderStudioStepScaffold extends StatelessWidget {
  const BorderStudioStepScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(title: title, description: description),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
