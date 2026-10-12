import 'dart:io';

import 'package:avelune_design_system/avelune_design_system.dart' as canonical;
import 'package:avelune_design_system/presentation/theme/studio_tokens.dart'
    as canonical_tokens;
import 'package:avelune_studio/avelune_design_system.dart' as studio;
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart'
    as studio_button;
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_badge.dart'
    as studio_badge;
import 'package:avelune_studio/presentation/theme/studio_tokens.dart'
    as studio_tokens;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Converter depends on the canonical design system without Studio', () {
    final specification = File('../avelune_converter/pubspec.yaml')
        .readAsStringSync();
    expect(specification, isNot(contains('  avelune_studio:')));
    expect(specification, contains('  avelune_design_system:'));
  });

  test('Studio exports the canonical widget, enum and token types', () {
    expect(
      <Type>[
        studio.StudioButton,
        studio.StudioButtonVariant,
        studio.StudioBadge,
        studio.StudioTone,
        studio.StudioEmptyState,
        studio.StudioNotice,
        studio.StudioChoice,
        studio.StudioDraftField,
        studio.StudioPathField,
        studio.StudioSearchField,
        studio.StudioSelect,
        studio.StudioTool,
        studio.StudioToggleRow,
        studio.StudioPageHeader,
        studio.StudioPanel,
        studio.StudioSection,
        studio.StudioSidebar,
        studio.StudioActionBar,
        studio.StudioAssetPreview,
        studio.StudioReviewDialog,
        studio.StudioColors,
        studio.StudioMetrics,
      ],
      <Type>[
        canonical.StudioButton,
        canonical.StudioButtonVariant,
        canonical.StudioBadge,
        canonical.StudioTone,
        canonical.StudioEmptyState,
        canonical.StudioNotice,
        canonical.StudioChoice,
        canonical.StudioDraftField,
        canonical.StudioPathField,
        canonical.StudioSearchField,
        canonical.StudioSelect,
        canonical.StudioTool,
        canonical.StudioToggleRow,
        canonical.StudioPageHeader,
        canonical.StudioPanel,
        canonical.StudioSection,
        canonical.StudioSidebar,
        canonical.StudioActionBar,
        canonical.StudioAssetPreview,
        canonical.StudioReviewDialog,
        canonical.StudioColors,
        canonical.StudioMetrics,
      ],
    );
    expect(studio_button.StudioButton, canonical.StudioButton);
    expect(studio_badge.StudioTone, canonical.StudioTone);
  });

  test('both theme entry points preserve the same ThemeExtension identity', () {
    for (final theme in [studio.studioTheme(), canonical.studioTheme()]) {
      final colors = theme.extension<canonical.StudioColors>();
      expect(colors, isNotNull);
      expect(theme.extension<studio.StudioColors>(), same(colors));
      expect(theme.extension<studio_tokens.StudioColors>(), same(colors));
      final updated = colors!.copyWith(success: theme.colorScheme.error);
      final adapted = theme.copyWith(extensions: [updated]);
      expect(adapted.extension<studio.StudioColors>(), same(updated));
    }
    expect(studio.studioTheme, same(canonical.studioTheme));
  });

  test('the complete tokens facade preserves Pokemon type colors', () {
    expect(
      studio_tokens.StudioPokemonTypeColors,
      canonical_tokens.StudioPokemonTypeColors,
    );
    expect(
      studio_tokens.StudioPokemonTypeColors.forType(
        'plant',
        studio.studioTheme().colorScheme.error,
      ),
      same(canonical_tokens.StudioPokemonTypeColors.grass),
    );
    expect(
      studio_tokens.StudioPokemonTypeColors.water,
      same(canonical_tokens.StudioPokemonTypeColors.water),
    );
  });

  testWidgets('Studio facades render canonical widgets and theme extensions', (
    tester,
  ) async {
    var presses = 0;
    final base = canonical.studioTheme();
    final colors = const canonical.StudioColors().copyWith(
      warning: base.colorScheme.error,
    );
    Color? facadeTone;
    Color? canonicalTone;
    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(extensions: [colors]),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              facadeTone = studio_badge.StudioToneColor(
                studio.StudioTone.warning,
              ).color(context);
              canonicalTone = canonical.StudioToneColor(
                canonical.StudioTone.warning,
              ).color(context);
              return Column(
                children: [
                  studio.StudioButton(
                    label: 'Partager le thème',
                    onPressed: () => presses++,
                  ),
                  const studio.StudioBadge(
                    'Attention',
                    tone: studio.StudioTone.warning,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(find.byType(canonical.StudioButton), findsOneWidget);
    expect(find.byType(canonical.StudioBadge), findsOneWidget);
    expect(facadeTone, canonicalTone);
    expect(facadeTone, colors.warning);
    await tester.tap(find.text('Partager le thème'));
    expect(presses, 1);
    expect(tester.takeException(), isNull);
  });
}
