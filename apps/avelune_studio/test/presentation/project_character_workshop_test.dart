import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/rendering/contracts/scoped_resource_preview_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/presentation/features/resources/project_character_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('previews the configured poses and pauses off the library tab', (
    tester,
  ) async {
    var reads = 0;
    final previews = ProjectResourcePreviews((entry) async {
      expect(entry.identity, 'character:garden-guide');
      reads++;
      return _project;
    });
    final visuals = _CharacterVisuals();
    Future<void> show({required bool active}) =>
        tester.pumpWidget(_workshop(previews, visuals, active: active));

    await show(active: true);
    await tester.pumpAndSettle();
    expect(visuals.last.animationState, CharacterAnimationState.idle);
    expect(visuals.last.facing, EntityFacing.south);
    expect(visuals.last.elapsedMs, 0);

    await _select(tester, 'Animation', 'Marche');
    expect(visuals.last.animationState, CharacterAnimationState.walk);
    await tester.tap(find.widgetWithText(StudioSelect, 'Direction'));
    await tester.pumpAndSettle();
    expect(find.text('Nord'), findsNothing);
    await tester.tap(find.text('Est').last);
    await tester.pumpAndSettle();
    expect(visuals.last.facing, EntityFacing.east);

    await tester.tap(find.text('Lecture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(visuals.last.elapsedMs, greaterThan(0));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    final paused = visuals.last.elapsedMs;
    await tester.pump(const Duration(milliseconds: 350));
    expect(visuals.last.elapsedMs, paused);

    await tester.tap(find.text('Lecture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(visuals.last.elapsedMs, greaterThan(paused));
    await show(active: false);
    final hidden = visuals.last.elapsedMs;
    await tester.pump(const Duration(seconds: 1));
    await show(active: true);
    await tester.pumpAndSettle();
    expect(visuals.last.elapsedMs, hidden);
    expect(find.text('Lecture'), findsOneWidget);
    expect(reads, 1);
  });

  testWidgets('plays a non-looping clip once and can replay it', (
    tester,
  ) async {
    final visuals = _CharacterVisuals();
    await tester.pumpWidget(
      _workshop(ProjectResourcePreviews((_) async => _project), visuals),
    );
    await tester.pumpAndSettle();
    await _select(tester, 'Animation', 'Coupe');
    await tester.tap(find.text('Lecture'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(visuals.last.elapsedMs, 199);
    expect(find.text('Lecture'), findsOneWidget);
    await tester.tap(find.text('Lecture'));
    await tester.pump();
    expect(visuals.last.elapsedMs, 0);
  });

  testWidgets('renames via the library action and keeps the selected preview', (
    tester,
  ) async {
    final visuals = _CharacterVisuals();
    var name = _character.name;
    var reads = 0;
    var renamed = 0;
    var wentBack = false;
    final previews = ProjectResourcePreviews((_) async {
      reads++;
      return _project;
    });
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _workshop(
          previews,
          visuals,
          name: name,
          onRename: () async => setState(() {
            renamed++;
            name = 'Guide des dunes';
          }),
          onBack: () => wentBack = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_character.name), findsOneWidget);
    await _select(tester, 'Animation', 'Marche');
    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();
    expect(renamed, 1);
    expect(find.text('Guide des dunes'), findsOneWidget);
    expect(find.text(_character.name), findsNothing);
    expect(visuals.last.animationState, CharacterAnimationState.walk);
    expect(reads, 1);
    await tester.tap(find.text('Retour à la bibliothèque'));
    expect(wentBack, isTrue);
  });

  testWidgets('retries a failed read and handles a character with no clip', (
    tester,
  ) async {
    final visuals = _CharacterVisuals();
    var reads = 0;
    await tester.pumpWidget(
      _workshop(
        ProjectResourcePreviews((_) async {
          if (++reads == 1) throw StateError('preview failed');
          return _project.copyWith(
            characters: [_character.copyWith(animations: [])],
          );
        }),
        visuals,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Impossible de lire le personnage'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune animation renseignée.'), findsOneWidget);
    expect(find.text('Lecture'), findsNothing);
    expect(visuals.last.elapsedMs, 0);
    expect(reads, 2);
  });
}

Future<void> _select(WidgetTester tester, String field, String value) async {
  await tester.tap(find.widgetWithText(StudioSelect, field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Widget _workshop(
  ProjectResourcePreviews previews,
  _CharacterVisuals visuals, {
  bool active = true,
  String name = 'Guide du jardin',
  Future<void> Function()? onRename,
  VoidCallback? onBack,
}) => MaterialApp(
  home: Scaffold(
    body: ProjectCharacterWorkshop(
      item: ProjectLibraryItem(
        kind: 'character',
        id: _character.id,
        name: name,
      ),
      previews: previews,
      visuals: visuals,
      active: active,
      onBack: onBack ?? () {},
      onRename: onRename,
    ),
  ),
);

const _project = ProjectManifest(
  name: 'Jardin',
  maps: [],
  tilesets: [],
  characters: [_character],
);

const _character = ProjectCharacterEntry(
  id: 'garden-guide',
  name: 'Guide du jardin',
  tilesetId: 'guide',
  animations: [
    CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.south,
      frames: [_firstFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.south,
      frames: [_firstFrame, _secondFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.east,
      frames: [_firstFrame, _secondFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.north,
    ),
    CharacterAnimation(
      state: CharacterAnimationState.cut,
      direction: EntityFacing.west,
      frames: [_firstFrame, _secondFrame],
      loop: false,
    ),
  ],
);

const _firstFrame = CharacterAnimationFrame(
  source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 32),
  durationMs: 100,
);
const _secondFrame = CharacterAnimationFrame(
  source: TilesetSourceRect(x: 16, y: 0, width: 16, height: 32),
  durationMs: 100,
);

class _CharacterVisuals extends WorkspaceTestVisuals
    implements ScopedResourcePreviewVisuals {
  late CharacterPreviewSource last;

  @override
  Widget scopedResourcePreview(
    ResourcePreviewSource source,
    ProjectManifest project, {
    required double size,
  }) {
    last = source as CharacterPreviewSource;
    return SizedBox.square(dimension: size);
  }

  @override
  void refreshResourcePreviews() {}

  @override
  void invalidateResourcePreviews(Set<String> changedRelativePaths) {}
}
