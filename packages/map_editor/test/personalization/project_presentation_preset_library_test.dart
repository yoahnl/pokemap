import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/presentation/project_presentation_preset_library.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

void main() {
  testWidgets('shows versioned presets and routes guided library actions', (
    tester,
  ) async {
    ProjectPresentationPresetRecord? applied;
    ProjectPresentationPresetRecord? deleted;
    var imported = false;
    var exported = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectPresentationPresetLibrary(
              presets: const <ProjectPresentationPresetRecord>[_preset],
              canManage: true,
              onApply: (preset) => applied = preset,
              onDelete: (preset) => deleted = preset,
              onImport: () => imported = true,
              onExport: () => exported = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Profil Hanazuki'), findsOneWidget);
    expect(find.text('v4'), findsOneWidget);
    expect(find.textContaining('.pokemapstyle'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('preset-library-import')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('preset-library-export')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('preset-apply-hanazuki')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('preset-delete-hanazuki')),
    );
    await tester.pump();

    expect(imported, isTrue);
    expect(exported, isTrue);
    expect(applied, _preset);
    expect(deleted, _preset);
  });

  testWidgets('disables durable actions while the draft is dirty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectPresentationPresetLibrary(
            presets: const <ProjectPresentationPresetRecord>[_preset],
            canManage: false,
            onApply: (_) {},
            onDelete: (_) {},
            onImport: () {},
            onExport: () {},
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey<String>('preset-library-import')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey<String>('preset-apply-hanazuki')),
          )
          .onPressed,
      isNotNull,
    );
  });
}

const _preset = ProjectPresentationPresetRecord(
  id: 'hanazuki',
  label: 'Profil Hanazuki',
  description: 'Identité claire pour le train de 17h42.',
  profile: ProjectPresentationProfile(
    branding: ProjectBrandingProfile(accentColor: '#5B68F6'),
  ),
);
